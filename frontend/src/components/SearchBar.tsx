/**
 * Controlled search input.
 */

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
}

export function SearchBar({ value, onChange }: SearchBarProps) {
  return (
    <div className="relative mb-6">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-muted)]">
        🔍
      </span>
      <input
        type="search"
        placeholder="Search songs..."
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="pl-9 w-full bg-[var(--surface-2)] border border-[var(--border)] rounded-lg py-2.5 text-sm focus:border-[var(--brand)] outline-none transition-colors"
      />
    </div>
  );
}
