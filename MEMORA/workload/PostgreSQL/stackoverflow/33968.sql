WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserActivity
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.HistoryDate,
    ph.PostHistoryTypeId,
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalVotes,
    ua.UpVotes,
    ua.DownVotes,
    tu.PostRank
FROM 
    RecursivePostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    UserActivity ua ON p.OwnerUserId = ua.UserId
JOIN 
    TopUsers tu ON ua.UserId = tu.UserId
WHERE 
    ph.rn = 1 
    AND ua.TotalPosts > 10 
    AND ph.PostHistoryTypeId IN (10, 11) 
ORDER BY 
    ph.HistoryDate DESC,
    ua.TotalPosts DESC;