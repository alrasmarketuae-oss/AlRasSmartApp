namespace BusinessLayer.Helpers;

public static class Mp4FastStartHelper
{
    private sealed record Atom(int Offset, int Size, string Type);

    public static async Task TryOptimizeInPlaceAsync(string filePath, CancellationToken ct = default)
    {
        var bytes = await File.ReadAllBytesAsync(filePath, ct);
        var optimized = TryFastStart(bytes);
        if (optimized is null)
        {
            return;
        }

        if (optimized.Length == bytes.Length && bytes.AsSpan().SequenceEqual(optimized))
        {
            return;
        }

        await File.WriteAllBytesAsync(filePath, optimized, ct);
    }

    public static byte[]? TryFastStart(ReadOnlySpan<byte> input)
    {
        if (input.Length < 16)
        {
            return null;
        }

        var atoms = ParseTopLevelAtoms(input);
        var moov = atoms.FirstOrDefault(a => a.Type == "moov");
        var mdat = atoms.FirstOrDefault(a => a.Type == "mdat");
        if (moov is null || mdat is null || moov.Offset < mdat.Offset)
        {
            return null;
        }

        using var output = new MemoryStream(input.Length);
        foreach (var atom in atoms.Where(a => a.Offset < mdat.Offset && a.Type != "moov"))
        {
            WriteAtomSlice(input, output, atom);
        }

        WriteAtomSlice(input, output, moov);
        WriteAtomSlice(input, output, mdat);

        foreach (var atom in atoms.Where(a => a.Offset > moov.Offset && a.Type is not "moov" and not "mdat"))
        {
            WriteAtomSlice(input, output, atom);
        }

        return output.ToArray();
    }

    private static void WriteAtomSlice(ReadOnlySpan<byte> input, MemoryStream output, Atom atom)
    {
        var start = (int)output.Length;
        output.SetLength(start + atom.Size);
        input.Slice(atom.Offset, atom.Size).CopyTo(output.GetBuffer().AsSpan(start, atom.Size));
    }

    private static List<Atom> ParseTopLevelAtoms(ReadOnlySpan<byte> input)
    {
        var atoms = new List<Atom>();
        var offset = 0;

        while (offset + 8 <= input.Length)
        {
            var size = ReadUInt32Be(input, offset);
            var type = ReadType(input, offset + 4);
            if (size < 8)
            {
                break;
            }

            long atomSize = size;
            var headerSize = 8;
            if (size == 1)
            {
                if (offset + 16 > input.Length)
                {
                    break;
                }

                atomSize = (long)ReadUInt64Be(input, offset + 8);
                headerSize = 16;
            }
            else if (size == 0)
            {
                atomSize = input.Length - offset;
            }

            if (atomSize < headerSize || offset + atomSize > input.Length)
            {
                break;
            }

            atoms.Add(new Atom(offset, (int)atomSize, type));
            offset += (int)atomSize;
        }

        return atoms;
    }

    private static string ReadType(ReadOnlySpan<byte> input, int offset)
    {
        Span<char> chars = stackalloc char[4];
        for (var i = 0; i < 4; i++)
        {
            chars[i] = (char)input[offset + i];
        }

        return new string(chars);
    }

    private static uint ReadUInt32Be(ReadOnlySpan<byte> input, int offset) =>
        ((uint)input[offset] << 24)
        | ((uint)input[offset + 1] << 16)
        | ((uint)input[offset + 2] << 8)
        | input[offset + 3];

    private static ulong ReadUInt64Be(ReadOnlySpan<byte> input, int offset) =>
        ((ulong)ReadUInt32Be(input, offset) << 32) | ReadUInt32Be(input, offset + 4);
}
