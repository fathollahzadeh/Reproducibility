
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.OwnerUserId, p.CreationDate
),
TopContributors AS (
    SELECT 
        Owner,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        COUNT(PostId) AS QuestionCount
    FROM 
        RankedPosts
    WHERE 
        UserPostRank <= 10 
    GROUP BY 
        Owner
),
BadgeCounts AS (
    SELECT 
        u.DisplayName AS UserName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tc.Owner,
    tc.TotalComments,
    tc.TotalAnswers,
    tc.QuestionCount,
    COALESCE(bc.BadgeCount, 0) AS BadgeCount
FROM 
    TopContributors tc
LEFT JOIN 
    BadgeCounts bc ON tc.Owner = bc.UserName
ORDER BY 
    tc.TotalComments DESC, tc.TotalAnswers DESC, tc.QuestionCount DESC;
