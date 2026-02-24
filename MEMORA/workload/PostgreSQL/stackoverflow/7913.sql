
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        PostCount,
        Questions,
        Answers,
        CommentCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserActivity
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.PostCount,
    t.Questions,
    t.Answers,
    t.CommentCount,
    bh.Name AS BadgeName,
    COUNT(DISTINCT ph.Id) AS PostHistoryCount
FROM 
    TopUsers t
LEFT JOIN 
    Badges b ON t.UserId = b.UserId AND b.Class = 1  
LEFT JOIN 
    PostHistory ph ON t.UserId = ph.UserId
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id
WHERE 
    t.UserRank <= 10
GROUP BY 
    t.UserId, t.DisplayName, t.PostCount, t.Questions, t.Answers, t.CommentCount, bh.Name
ORDER BY 
    t.PostCount DESC;
