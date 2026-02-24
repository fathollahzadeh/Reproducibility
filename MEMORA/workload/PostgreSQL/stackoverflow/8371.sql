
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewPosts,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS AnsweredQuestions
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.HighViewPosts,
        us.AnsweredQuestions,
        RANK() OVER (ORDER BY us.HighViewPosts DESC, us.AnsweredQuestions DESC) AS UserRank
    FROM UserStats us
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    tu.DisplayName AS TopUser,
    tu.PostCount AS UserPostCount,
    tu.HighViewPosts AS UserHighViewPosts,
    tu.AnsweredQuestions AS UserAnsweredQuestions
FROM RankedPosts rp
JOIN TopUsers tu ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId ORDER BY p.Score DESC LIMIT 1)
WHERE rp.Rank <= 10
ORDER BY rp.Score DESC, rp.ViewCount DESC;
