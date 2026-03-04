export function safeLower(s) {
  return String(s ?? '').toLowerCase();
}

export function filterByTerm(rows, fields, term) {
  const t = String(term || '').trim().toLowerCase();
  if (!t) return rows || [];
  return (rows || []).filter(r => (fields || []).some(f => safeLower(r?.[f]).includes(t)));
}

export function groupCounts(diffBucket) {
  return {
    onlyA: diffBucket?.onlyA?.length || 0,
    onlyB: diffBucket?.onlyB?.length || 0,
    both: diffBucket?.both?.length || 0
  };
}
