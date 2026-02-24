WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotesCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostStatistics AS (
    SELECT 
        t.PostId,
        t.Title,
        t.Score,
        t.ViewCount,
        COALESCE(rv.UpVotesCount, 0) AS UpVotesCount,
        COALESCE(rv.DownVotesCount, 0) AS DownVotesCount,
        t.Reputation,
        CASE 
            WHEN t.Score >= 10 THEN 'Popular'
            WHEN t.Reputation >= 1000 THEN 'Influencer'
            ELSE 'Regular'
        END AS Classification
    FROM 
        TopRankedPosts t
    LEFT JOIN 
        RecentVotes rv ON t.PostId = rv.PostId
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount
    FROM 
        PostHistory ph
    GROUP BY 
        PostId
)
SELECT 
    ps.Title,
    ps.Score,
    ps.UpVotesCount,
    ps.DownVotesCount,
    ps.Classification,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ps.ViewCount,
    CASE 
        WHEN ps.UpVotesCount > ps.DownVotesCount THEN 'Positive'
        WHEN ps.UpVotesCount < ps.DownVotesCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    (ps.UpVotesCount + ps.DownVotesCount) > 10
ORDER BY 
    ps.Score DESC, 
    ps.Reputation DESC, 
    ps.ViewCount DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;