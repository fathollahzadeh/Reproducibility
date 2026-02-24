
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
), 
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(p.ViewCount) AS AverageViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
), 
PostClosureHistory AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseVotes,
        STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INT) = ct.Id 
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.UserId
), 
UserPerformance AS (
    SELECT 
        ur.UserId, 
        ur.DisplayName,
        ur.Reputation,
        us.QuestionCount,
        us.AcceptedAnswers,
        us.AverageViews,
        COALESCE(pch.CloseVotes, 0) AS TotalCloseVotes,
        COALESCE(pch.CloseReasonNames, 'None') AS CloseReasons
    FROM 
        UserReputation ur
    LEFT JOIN 
        QuestionStats us ON ur.UserId = us.OwnerUserId
    LEFT JOIN 
        PostClosureHistory pch ON ur.UserId = pch.UserId
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    QuestionCount,
    AcceptedAnswers,
    AverageViews,
    TotalCloseVotes,
    CloseReasons
FROM 
    UserPerformance
WHERE 
    Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND QuestionCount > 0 
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = UserId AND p.ClosedDate IS NOT NULL
    )
ORDER BY 
    Reputation DESC, QuestionCount DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;
