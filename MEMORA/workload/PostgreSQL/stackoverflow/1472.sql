WITH UserRanked AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
PostsWithAnswers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, u.DisplayName, p.Score, p.AnswerCount
),
PopularPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.OwnerDisplayName,
        p.Score,
        p.CommentCount,
        CASE 
            WHEN p.Score > 5 THEN 'Hot'
            WHEN p.Score BETWEEN 1 AND 5 THEN 'Moderate'
            ELSE 'Cold'
        END AS Popularity
    FROM PostsWithAnswers p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostHistoryWithCloseReason AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        p.OwnerDisplayName,
        ph.Comment AS CloseReason
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (10, 11) 
),
FinalResult AS (
    SELECT 
        pp.Title,
        pp.OwnerDisplayName,
        pp.Score,
        pp.AnswerCount,
        pp.CommentCount,
        pp.Popularity,
        COALESCE(ph.CloseReason, 'N/A') AS LastCloseReason
    FROM PopularPosts pp
    LEFT JOIN PostHistoryWithCloseReason ph ON pp.PostId = ph.PostId
)

SELECT 
    f.Title,
    f.OwnerDisplayName,
    f.Score,
    f.AnswerCount,
    f.CommentCount,
    f.Popularity,
    f.LastCloseReason,
    ur.ReputationRank
FROM FinalResult f
JOIN UserRanked ur ON f.OwnerDisplayName = ur.DisplayName
WHERE ur.ReputationRank <= 10
ORDER BY f.Score DESC, f.CommentCount DESC;