WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND p.Score IS NOT NULL
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.AcceptedAnswerId IS NOT NULL
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment,
        ph.UserDisplayName
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (10, 11)  
),
PostTagCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM Posts p
    JOIN Tags tg ON tg.WikiPostId = p.Id
    LEFT JOIN Tags t ON t.ExcerptPostId = p.Id
    GROUP BY p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.Score,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    COALESCE(ps.UniqueVoterCount, 0) AS UniqueVoterCount,
    tc.TagCount,
    cp.ClosedDate,
    cp.Comment AS CloseComment,
    cp.UserDisplayName AS ClosedBy
FROM RankedPosts rp
LEFT JOIN PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN PostTagCount tc ON rp.PostId = tc.PostId
LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE rp.Rank <= 5  
ORDER BY rp.Rank, rp.Score DESC, rp.CreationDate DESC;