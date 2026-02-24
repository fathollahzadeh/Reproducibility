
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(a.Id) AS AnswerCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.OwnerUserId, p.CreationDate, p.AcceptedAnswerId
    HAVING COUNT(a.Id) >= 5 AND p.ViewCount > 100
),
BadgesWithComments AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM Badges b
    LEFT JOIN Comments c ON b.UserId = c.UserId
    GROUP BY b.UserId
),
AggregatedVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeleteVotes,
        SUM(CASE WHEN v.VoteTypeId = 9 THEN 1 ELSE 0 END) AS BountyCloseVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
FinalResult AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ur.Reputation,
        ur.ReputationRank,
        tq.QuestionId,
        tq.Title AS QuestionTitle,
        tq.AnswerCount,
        bw.BadgeCount,
        av.UpVotes,
        av.DownVotes,
        av.DeleteVotes,
        av.BountyCloseVotes
    FROM UserReputation ur
    INNER JOIN Users u ON ur.UserId = u.Id
    LEFT JOIN TopQuestions tq ON tq.OwnerUserId = u.Id
    LEFT JOIN BadgesWithComments bw ON bw.UserId = u.Id
    LEFT JOIN AggregatedVotes av ON tq.QuestionId = av.PostId
)

SELECT 
    UserId,
    DisplayName,
    Reputation,
    ReputationRank,
    QuestionId,
    QuestionTitle,
    AnswerCount,
    BadgeCount,
    UpVotes,
    DownVotes,
    DeleteVotes,
    BountyCloseVotes
FROM FinalResult
WHERE ReputationRank <= 10
AND (UpVotes - DownVotes) > 0
ORDER BY Reputation DESC, AnswerCount DESC, UserId;
