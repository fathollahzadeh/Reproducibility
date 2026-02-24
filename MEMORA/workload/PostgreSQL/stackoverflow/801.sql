
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        U.Reputation AS UserReputation,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, U.Reputation, p.PostTypeId
),
PostStats AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount, 
        rp.Rank, 
        rp.UserReputation, 
        CASE 
            WHEN rp.UserReputation IS NULL THEN 'N/A' 
            WHEN rp.UserReputation < 100 THEN 'Low Reputation' 
            WHEN rp.UserReputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation' 
        END AS ReputationCategory
    FROM 
        RankedPosts rp
),
ClosedPosts AS (
    SELECT 
        DISTINCT ph.PostId 
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAYS'
)
SELECT 
    ps.Title, 
    ps.Score, 
    ps.ViewCount, 
    ps.Rank, 
    ps.ReputationCategory, 
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed'
        ELSE 'Open' 
    END AS PostStatus
FROM 
    PostStats ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.Rank <= 10
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
