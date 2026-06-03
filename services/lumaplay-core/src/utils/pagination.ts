export function paginate<T>(
  items: T[],
  page = 1,
  limit = 50,
) {
  const start = (page - 1) * limit;
  const end = start + limit;

  return {
    page,
    limit,
    total: items.length,
    pages: Math.ceil(items.length / limit),
    items: items.slice(start, end),
  };
}