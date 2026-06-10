/**
 * Search input for filtering songs.
 */

interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
}

export function SearchBar({ value, onChange }: SearchBarProps) {
  return (
    <input
      type="search"
      className="search-bar"
      placeholder="Search by title, artist, or album..."
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  );
}
