
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        p.AcceptedAnswerId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score > 0 
        AND p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.PostRank = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pu.DisplayName,
    ps.Title,
    ps.RecentVoteCount,
    ps.ViewCount,
    ps.Score,
    ps.Tags,
    CASE 
        WHEN ps.RecentVoteCount = 0 THEN 'No recent votes'
        ELSE 'Votes recorded'
    END AS VoteStatus,
    CASE
        WHEN ps.Score > 100 THEN 'Highly Rated'
        WHEN ps.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingStatus
FROM 
    PostStatistics ps
JOIN 
    Users pu ON ps.PostId IN (
        SELECT DISTINCT PostId FROM Posts WHERE OwnerUserId = pu.Id
    )
WHERE 
    pu.Id IN (SELECT UserId FROM TopUsers WHERE UserRank <= 10)
ORDER BY 
    ps.Score DESC, ps.RecentVoteCount DESC
LIMIT 50;
