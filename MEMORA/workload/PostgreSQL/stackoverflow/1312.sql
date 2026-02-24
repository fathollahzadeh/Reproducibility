WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.Score) AS AverageScore,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentChanges AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ChangeRank
    FROM 
        PostHistory ph
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AverageScore,
    COALESCE(rc.RecentChange, 'No changes') AS RecentChange,
    COALESCE(rc.Comment, 'No comment') AS ChangeComment
FROM 
    UserPostStats ups
LEFT JOIN 
    (
        SELECT 
            r.UserId,
            r.PostId,
            r.Comment AS RecentChange,
            r.CreationDate,
            r.Comment
        FROM 
            RecentChanges r
        WHERE 
            r.ChangeRank = 1
    ) rc ON ups.UserId = rc.UserId
WHERE 
    ups.PostCount > 5
ORDER BY 
    ups.AverageScore DESC
LIMIT 10 OFFSET 5;
