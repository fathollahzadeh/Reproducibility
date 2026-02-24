
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
),

UserVoteCount AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),

TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(uv.TotalVotes, 0) AS TotalVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC, COALESCE(uv.TotalVotes, 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserVoteCount uv ON u.Id = uv.UserId
    WHERE 
        u.Reputation > 100 
),

LatestPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 19) 
)

SELECT 
    tp.DisplayName,
    tp.Reputation,
    tp.TotalVotes,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    COALESCE(LPH.Comment, 'No recent history') AS RecentHistoryComment,
    CASE 
        WHEN LPH.PostHistoryTypeId IS NOT NULL THEN 'Closed/Reopened/Deleted'
        ELSE 'Active'
    END AS PostStatus
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.Id = rp.OwnerUserId AND rp.PostRank = 1 
LEFT JOIN 
    LatestPostHistory LPH ON rp.PostId = LPH.PostId AND LPH.HistoryRank = 1 
WHERE 
    rp.PostId IS NOT NULL 
ORDER BY 
    tp.UserRank
LIMIT 50;
