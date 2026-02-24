
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        AcceptedAnswers,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
        AND ph.PostHistoryTypeId IN (10, 11, 12)
),
UserPostDetails AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        COALESCE(rp.RecentEditCount, 0) AS RecentEditCount,
        COALESCE(th.TopPostedCount, 0) AS TopPostedCount
    FROM 
        TopUsers u
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            COUNT(DISTINCT rp.PostId) AS RecentEditCount
        FROM 
            Posts p
        JOIN 
            RecentPostHistory rp ON p.Id = rp.PostId
        GROUP BY 
            p.OwnerUserId
    ) rp ON u.UserId = rp.OwnerUserId
    LEFT JOIN (
        SELECT 
            p.OwnerUserId,
            COUNT(*) AS TopPostedCount
        FROM 
            Posts p
        GROUP BY 
            p.OwnerUserId
        HAVING 
            COUNT(*) > 10
    ) th ON u.UserId = th.OwnerUserId
)
SELECT 
    ud.DisplayName,
    ud.RecentEditCount,
    ut.Reputation,
    ut.PostCount,
    ut.AnswerCount,
    ut.AcceptedAnswers,
    ud.TopPostedCount
FROM 
    UserPostDetails ud
JOIN 
    TopUsers ut ON ud.UserId = ut.UserId
ORDER BY 
    ut.Rank
LIMIT 10;
