
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id, 
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        COALESCE(SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes,
        COALESCE(MAX(po.Score), 0) AS MaxScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    LEFT JOIN 
        Posts po ON ph.PostId = po.Id
    LEFT JOIN 
        Comments c ON ph.PostId = c.PostId
    GROUP BY 
        ph.PostId, ph.Title, ph.Level
),
UserRanks AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.TotalBounties,
        ur.TotalUpvotes,
        ur.TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY ur.TotalBounties DESC) AS RankByBounties,
        ROW_NUMBER() OVER (ORDER BY ur.TotalUpvotes - ur.TotalDownvotes DESC) AS RankByReputation
    FROM 
        UserReputation ur
),
FinalResult AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Level,
        tp.TotalVotes,
        tp.MaxScore,
        tp.CommentCount,
        ur.DisplayName AS UserDisplayName,
        ur.TotalBounties,
        ur.RankByBounties,
        ur.RankByReputation
    FROM 
        TopPosts tp
    LEFT JOIN 
        Posts p ON tp.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserRanks ur ON u.Id = ur.UserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Level,
    fr.TotalVotes,
    fr.MaxScore,
    fr.CommentCount,
    fr.UserDisplayName,
    fr.TotalBounties,
    fr.RankByBounties,
    fr.RankByReputation
FROM 
    FinalResult fr
WHERE 
    fr.MaxScore > 0
ORDER BY 
    fr.MaxScore DESC, fr.CommentCount DESC
LIMIT 50;
