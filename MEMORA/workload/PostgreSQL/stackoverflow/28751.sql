
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High'
            WHEN u.Reputation BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS ReputationLevel
    FROM Users u
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        ur.DisplayName,
        ur.ReputationLevel,
        COUNT(a.Id) AS AnswerCount
    FROM RankedPosts rp
    JOIN UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN Posts a ON rp.PostId = a.ParentId
    GROUP BY rp.PostId, rp.Title, rp.ViewCount, ur.DisplayName, ur.ReputationLevel
    ORDER BY rp.ViewCount DESC
    LIMIT 10
),
VoteDetails AS (
    SELECT 
        p.Id AS PostId, 
        v.VoteTypeId, 
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, v.VoteTypeId
)
SELECT 
    tq.PostId,
    tq.Title,
    tq.ViewCount,
    tq.DisplayName,
    tq.ReputationLevel,
    COALESCE(SUM(CASE WHEN vd.VoteTypeId = 2 THEN vd.VoteCount ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN vd.VoteTypeId = 3 THEN vd.VoteCount ELSE 0 END), 0) AS DownVotes,
    COALESCE(SUM(CASE WHEN vd.VoteTypeId = 6 THEN vd.VoteCount ELSE 0 END), 0) AS CloseVotes,
    tq.AnswerCount
FROM TopQuestions tq
LEFT JOIN VoteDetails vd ON tq.PostId = vd.PostId
GROUP BY 
    tq.PostId, 
    tq.Title, 
    tq.ViewCount, 
    tq.DisplayName, 
    tq.ReputationLevel,
    tq.AnswerCount
ORDER BY tq.ViewCount DESC;
