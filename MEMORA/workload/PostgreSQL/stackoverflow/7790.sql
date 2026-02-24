WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.VoteCount, 0)) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
RecentComments AS (
    SELECT 
        c.PostId,
        c.UserDisplayName,
        c.Text,
        c.CreationDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '7 days'
)
SELECT 
    rp.Title,
    rp.ViewCount,
    tu.DisplayName AS PostOwner,
    tu.TotalPosts,
    tu.TotalBadges,
    tu.TotalVotes,
    rc.UserDisplayName AS Commenter,
    rc.Text AS CommentText,
    rc.CreationDate AS CommentDate
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = tu.UserId)
LEFT JOIN 
    RecentComments rc ON rc.PostId = rp.PostId
WHERE 
    rp.ViewRank <= 5
ORDER BY 
    rp.ViewCount DESC, 
    rc.CreationDate DESC
LIMIT 100;