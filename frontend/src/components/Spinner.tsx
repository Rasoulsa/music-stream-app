/**
 * Minimal loading indicator.
 */

export default function Spinner() {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '40vh',
        color: '#888',
      }}
    >
      Loading…
    </div>
  );
}
