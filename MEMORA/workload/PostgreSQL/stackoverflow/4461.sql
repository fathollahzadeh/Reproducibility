
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserId AS ClosureUserId
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10
),

TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        ROW_NUMBER() OVER (ORDER BY us.Reputation DESC) AS TopRank
    FROM 
        UserStats us
    WHERE 
        us.Reputation > 1000
)

SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation,
    cp.Title AS ClosedPostTitle,
    cp.ClosedDate,
    u.DisplayName AS ClosedByUser
FROM 
    ClosedPosts cp
LEFT JOIN 
    TopUsers tu ON cp.ClosedPostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = tu.UserId
    )
LEFT JOIN 
    Users u ON cp.ClosureUserId = u.Id
WHERE 
    tu.TopRank <= 10 
ORDER BY 
    tu.Reputation DESC, cp.ClosedDate DESC;
