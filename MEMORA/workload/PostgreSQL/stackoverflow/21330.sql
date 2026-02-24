
WITH UserRankings AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY CreationDate DESC) AS Rank
    FROM Users
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        COALESCE(a.Body, 'No Answer') AS AcceptedAnswerBody,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY p.Id, a.Body
),
Metrics AS (
    SELECT 
        ud.UserId,
        ud.Reputation,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        pd.PostId,
        pd.Title,
        pd.PostCreationDate,
        pd.ViewCount,
        pd.AcceptedAnswerBody,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        RANK() OVER (PARTITION BY ud.UserId ORDER BY pd.ViewCount DESC) AS PostRank
    FROM UserRankings ud
    JOIN UserBadges ub ON ud.UserId = ub.UserId
    JOIN PostDetails pd ON pd.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ud.UserId) 
    WHERE ud.Rank = 1
)
SELECT 
    m.UserId,
    u.DisplayName,
    m.Reputation,
    m.GoldBadges,
    m.SilverBadges,
    m.BronzeBadges,
    m.Title,
    m.PostCreationDate,
    m.ViewCount,
    m.AcceptedAnswerBody,
    m.CommentCount,
    m.UpVotes,
    m.DownVotes
FROM Metrics m
JOIN Users u ON m.UserId = u.Id 
WHERE m.PostRank <= 3
ORDER BY m.Reputation DESC, m.ViewCount DESC;
