WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        UP.Rank AS UserRank,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankWithinType,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            Id,
            CASE 
                WHEN Reputation >= 10000 THEN 'Elite'
                WHEN Reputation >= 1000 THEN 'Pro'
                ELSE 'Newbie' 
            END AS Rank
        FROM 
            Users
    ) UP ON u.Id = UP.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, UP.Rank
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
),
TopUpVotedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > rp.DownVoteCount THEN 'Positive scored'
            WHEN rp.UpVoteCount < rp.DownVoteCount THEN 'Negative scored'
            ELSE 'Equally scored'
        END AS VoteAnalysis
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserRank = 'Elite' OR (rp.UserRank IS NULL AND rp.UpVoteCount > 5)
)

SELECT 
    t.Title,
    t.Score,
    t.UpVoteCount,
    t.DownVoteCount,
    t.VoteAnalysis,
    ph.HistoryType,
    ph.HistoryDate,
    ph.UserDisplayName,
    COALESCE(NULLIF(ph.Text, ''), 'No comment provided') AS HistoryComment
FROM 
    TopUpVotedPosts t
LEFT JOIN 
    PostHistoryDetails ph ON t.PostId = ph.PostId AND ph.HistoryRank <= 3
WHERE 
    (ph.HistoryDate IS NULL OR ph.HistoryDate >= cast('2024-10-01' as date) - INTERVAL '30 days')
ORDER BY 
    t.Score DESC, 
    t.UpVoteCount DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM TopUpVotedPosts) / 2
;