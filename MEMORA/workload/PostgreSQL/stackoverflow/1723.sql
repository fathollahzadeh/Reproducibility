WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosed,
        SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS TotalEdited
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.TotalClosed, 0) AS TotalClosed,
        COALESCE(ps.TotalEdited, 0) AS TotalEdited
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.TotalPosts,
        ur.TotalClosed,
        ur.TotalEdited,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM 
        UserReputation ur
    WHERE 
        ur.Reputation > 1000
),
FinalOutput AS (
    SELECT 
        tu.UserId,
        tu.Reputation,
        tu.TotalPosts,
        tu.TotalClosed,
        tu.TotalEdited,
        tp.PostId AS TopPostId,
        tp.Title AS TopPostTitle,
        tp.ViewCount AS TopPostViewCount
    FROM 
        TopUsers tu
    LEFT JOIN 
        RankedPosts tp ON tu.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId LIMIT 1)
    WHERE 
        tu.UserRank <= 10
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    TotalClosed,
    TotalEdited,
    TopPostId,
    TopPostTitle,
    TopPostViewCount
FROM 
    FinalOutput
ORDER BY 
    Reputation DESC;