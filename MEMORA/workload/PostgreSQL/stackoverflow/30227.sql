WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),
RecentActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.OwnerUserId
),
UserStats AS (
    SELECT 
        tu.UserId,
        tu.DisplayName,
        tu.Reputation,
        COALESCE(ra.CommentCount, 0) AS CommentCount,
        ra.LastCommentDate,
        tu.QuestionCount,
        tu.TotalBounties
    FROM 
        TopUsers tu
    LEFT JOIN 
        RecentActivity ra ON tu.UserId = ra.OwnerUserId
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT ph.PostId) AS UniquePostEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.QuestionCount,
    us.TotalBounties,
    us.CommentCount,
    us.LastCommentDate,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    COALESCE(ph.UniquePostEdits, 0) AS UniquePostsEdited
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryStats ph ON us.UserId = ph.UserId
WHERE 
    us.Reputation > 1000 
ORDER BY 
    us.Reputation DESC,
    us.QuestionCount DESC;