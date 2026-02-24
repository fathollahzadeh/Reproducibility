
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(v.VoteCount, 0)) AS AvgVotes,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
), RecentActivity AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostCount,
    up.QuestionCount,
    up.AnswerCount,
    up.AvgVotes,
    cp.LastClosedDate,
    ra.CommentCount,
    ra.LastCommentDate,
    CASE 
        WHEN up.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    UserPostStats up
LEFT JOIN 
    ClosedPosts cp ON up.UserId = cp.PostId
LEFT JOIN 
    RecentActivity ra ON up.UserId = ra.PostId
WHERE 
    up.PostCount > 0
    AND (ra.LastCommentDate IS NULL OR ra.LastCommentDate > '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days')
ORDER BY 
    up.UserRank ASC, up.PostCount DESC;
