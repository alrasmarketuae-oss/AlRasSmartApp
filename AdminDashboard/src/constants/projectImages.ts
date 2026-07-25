/** مسارات أصول ProjectImages — كما في تصميم لوحة التحكم */
export const PROJECT_IMAGES = {
  logo: '/ProjectImages/SouqLogo.png',

  /** بطاقات الإحصائيات */
  statUsers: '/ProjectImages/users.png',
  statSuppliers: '/ProjectImages/Suppliers.png',
  statOrders: '/ProjectImages/Orders.png',
  statSales: '/ProjectImages/AEDCurrency.png',

  /** نشاط مباشر */
  activityNewOrder: '/ProjectImages/NewOrder.png',
  activityNewUser: '/ProjectImages/Newuser (2).png',
  activityShipping: '/ProjectImages/ShippingOrder.png',
  activityApproved: '/ProjectImages/OrderAccepted.png',
} as const

export const ACTIVITY_ICON_BY_TYPE: Record<string, string> = {
  order: PROJECT_IMAGES.activityNewOrder,
  user: PROJECT_IMAGES.activityNewUser,
  company: PROJECT_IMAGES.activityNewUser,
  shipping: PROJECT_IMAGES.activityShipping,
  approval: PROJECT_IMAGES.activityApproved,
  update: PROJECT_IMAGES.activityNewOrder,
}
