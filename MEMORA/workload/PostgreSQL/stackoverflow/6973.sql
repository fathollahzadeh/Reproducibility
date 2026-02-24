WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.OwnerUserId IS NOT NULL
      AND p.PostTypeId IN (1, 2)  
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(p.Score) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentlyEditedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastEditDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.QuestionsCount,
    tu.AnswersCount,
    tu.TotalScore,
    rp.PostId,
    rp.Title AS PostTitle,
    rp.CreationDate AS PostCreationDate,
    rp.Score AS PostScore,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    re.LastEditDate AS PostLastEditDate
FROM TopUsers tu
JOIN RankedPosts rp ON tu.UserId = rp.PostId 
LEFT JOIN RecentlyEditedPosts re ON rp.PostId = re.PostId
WHERE tu.UserRank <= 10  
  AND rp.PostRank <= 5    
ORDER BY tu.TotalScore DESC, rp.Score DESC;