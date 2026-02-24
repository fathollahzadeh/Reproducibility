
WITH UserPostCounts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount
    FROM 
        UserPostCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        u.DisplayName AS Author
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    ORDER BY 
        p.CreationDate DESC
    LIMIT 10
)

SELECT 
    u.DisplayName AS TopUser, 
    u.PostCount, 
    r.PostId, 
    r.Title AS RecentPostTitle, 
    r.CreationDate AS RecentPostDate, 
    r.Author
FROM 
    TopUsers u
FULL OUTER JOIN 
    RecentPosts r ON u.DisplayName = r.Author
ORDER BY 
    u.PostCount DESC, 
    r.CreationDate DESC;
