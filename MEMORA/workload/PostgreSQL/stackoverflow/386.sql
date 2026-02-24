
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5, 6) THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 0
    GROUP BY u.Id, u.DisplayName, u.Reputation
), CloseReasons AS (
    SELECT 
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM PostHistory ph
    LEFT JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INTEGER) = cr.Id
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId
), UserStats AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        ua.PostCount,
        ua.Questions,
        ua.Answers,
        ua.Wikis,
        COALESCE(cr.CloseReason, 'No Close Reason') AS CloseReason,
        ROW_NUMBER() OVER (ORDER BY ua.Reputation DESC) AS Rank
    FROM UserActivity ua
    LEFT JOIN CloseReasons cr ON ua.UserId = cr.PostId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.Questions,
    us.Answers,
    us.Wikis,
    us.CloseReason,
    CASE 
        WHEN us.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Contributor'
    END AS ContributorStatus
FROM UserStats us
WHERE us.PostCount > 10
ORDER BY us.Rank;
