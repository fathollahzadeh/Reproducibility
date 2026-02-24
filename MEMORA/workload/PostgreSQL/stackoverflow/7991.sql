
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        MAX(u.CreationDate) AS AccountCreation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
MostActiveUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.TotalPosts,
        us.Questions,
        us.Answers,
        us.AcceptedAnswers,
        us.AccountCreation,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS PostRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 0
),
TopCloseReason AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS CloseReasonsCount,
        cr.Name AS CloseReasonName
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId, cr.Name
),
UserCloseReasonRanked AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(SUM(tcrc.CloseReasonsCount), 0) AS TotalCloseReasons
    FROM 
        Users u
    LEFT JOIN 
        TopCloseReason tcrc ON u.Id = tcrc.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    mau.DisplayName AS MostActiveUser,
    mau.TotalPosts,
    mau.Questions,
    mau.Answers,
    mau.AcceptedAnswers,
    ucr.DisplayName AS UserWithMostCloseReasons,
    ucr.TotalCloseReasons
FROM 
    MostActiveUsers mau
JOIN 
    UserCloseReasonRanked ucr ON ucr.TotalCloseReasons = (SELECT MAX(TotalCloseReasons) FROM UserCloseReasonRanked)
WHERE 
    mau.PostRank <= 10
ORDER BY 
    mau.TotalPosts DESC, ucr.TotalCloseReasons DESC;
