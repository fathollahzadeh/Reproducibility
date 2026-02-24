
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(p.AvgScore, 0) AS AvgPostScore,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(b.TotalBadges, 0) AS TotalBadges
    FROM Users u
    LEFT JOIN (
        SELECT 
            OwnerUserId AS UserId,
            AVG(Score) AS AvgScore
        FROM Posts 
        WHERE PostTypeId IN (1, 2)  
        GROUP BY OwnerUserId
    ) p ON u.Id = p.UserId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(Id) AS CommentCount
        FROM Comments
        GROUP BY UserId
    ) c ON u.Id = c.UserId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(Id) AS TotalBadges
        FROM Badges
        GROUP BY UserId
    ) b ON u.Id = b.UserId
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        p.CreationDate,
        CASE
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0
        END AS HasAcceptedAnswer
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.LastActivityDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)
    GROUP BY ph.PostId, ph.UserDisplayName, ph.CreationDate, ph.Comment
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.AvgPostScore,
    ua.TotalComments,
    ua.TotalBadges,
    ap.Title,
    ap.HasAcceptedAnswer,
    ap.UpVotes,
    ap.DownVotes,
    ph.CloseReason,
    ph.HistoryDate,
    ph.CloseReopenCount,
    CASE 
        WHEN ap.HasAcceptedAnswer = 1 THEN 'Accepted Answer Preserved'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM UserActivity ua
JOIN ActivePosts ap ON ua.UserId = ap.PostId
LEFT JOIN PostHistoryDetails ph ON ap.PostId = ph.PostId
ORDER BY ua.Reputation DESC, ap.UpVotes DESC, ph.HistoryDate DESC
LIMIT 100 OFFSET 0;
