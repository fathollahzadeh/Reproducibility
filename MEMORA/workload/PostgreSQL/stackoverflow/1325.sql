
WITH RankedUsers AS (
    SELECT 
        u.Id, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE p.LastActivityDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.AcceptedAnswerId
),
PostDetails AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.CreationDate,
        ap.ViewCount,
        ap.CommentCount,
        ap.TotalBounties,
        CASE 
            WHEN ap.AcceptedAnswerId = 0 THEN 'No Answer Accepted'
            ELSE 'Answer Accepted'
        END AS AnswerStatus
    FROM ActivePosts ap
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.UserRank,
    pd.Title, 
    pd.CreationDate, 
    pd.ViewCount,
    pd.CommentCount, 
    pd.TotalBounties,
    pd.AnswerStatus,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypeNames
FROM RankedUsers ru
JOIN PostDetails pd ON ru.Id = pd.PostId
LEFT JOIN PostTypes pt ON pd.CommentCount > 0 AND pd.TotalBounties > 0
GROUP BY ru.Id, ru.DisplayName, ru.Reputation, ru.UserRank, pd.PostId, pd.Title, pd.CreationDate, pd.ViewCount, pd.CommentCount, pd.TotalBounties, pd.AnswerStatus
ORDER BY ru.UserRank, pd.ViewCount DESC
LIMIT 100;
