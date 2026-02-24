WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        TotalScore,
        QuestionCount,
        AnswerCount
    FROM RecursiveUserActivity
    WHERE UserRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(ph.UserDisplayName, 'No Edits') AS LastEditor,
        MAX(ph.CreationDate) AS LastEditDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, ph.UserDisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        LastEditor,
        LastEditDate
    FROM PostDetails
    WHERE PostRank <= 10
),
Awards AS (
    SELECT 
        b.UserId,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM Badges b
    GROUP BY b.UserId, b.Name
),
UserAwards AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(a.BadgeName, 'No Badge') AS BadgeName,
        COALESCE(a.BadgeCount, 0) AS BadgeCount
    FROM Users u
    LEFT JOIN Awards a ON u.Id = a.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalScore,
    tu.QuestionCount,
    tu.AnswerCount,
    tp.Title AS TopPostTitle,
    tp.CreationDate AS TopPostCreationDate,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.CommentCount AS TopPostCommentCount,
    tp.LastEditor AS TopPostLastEditor,
    tp.LastEditDate AS TopPostLastEditDate,
    ua.BadgeName,
    ua.BadgeCount
FROM TopUsers tu
JOIN TopPosts tp ON tp.CommentCount = ALL (
    SELECT CommentCount FROM TopPosts WHERE UserId = tu.UserId
)
LEFT JOIN UserAwards ua ON tu.UserId = ua.UserId
ORDER BY tu.TotalScore DESC;
