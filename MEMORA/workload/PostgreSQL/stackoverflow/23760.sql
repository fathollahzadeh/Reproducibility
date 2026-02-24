
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId <> u.Id
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), RankByActivity AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        UpvotesReceived,
        DownvotesReceived,
        CommentsMade,
        BadgesEarned,
        RANK() OVER (ORDER BY QuestionsAsked DESC, AnswersGiven DESC) AS ActivityRank
    FROM 
        UserActivity
), RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        pt.Name AS PostTypeName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '30 days')
), UserPostStats AS (
    SELECT 
        ra.DisplayName,
        ra.ActivityRank,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        CASE 
            WHEN rp.PostTypeId = 1 THEN 'Question'
            WHEN rp.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        COALESCE((SELECT COUNT(*) FROM Comments cm WHERE cm.PostId = rp.PostId), 0) AS CommentsOnPost
    FROM 
        RankByActivity ra
    INNER JOIN 
        RecentPosts rp ON ra.UserId = rp.OwnerUserId
)

SELECT 
    ups.DisplayName,
    ups.ActivityRank,
    ups.Title,
    ups.CreationDate,
    ups.PostType,
    ups.CommentsOnPost,
    CASE
        WHEN ups.ActivityRank = 1 THEN 'Top Contributor of the Month'
        WHEN ups.CommentsOnPost > 0 THEN 'Engaging with the Community'
        ELSE 'Just Another User'
    END AS UserStatus
FROM 
    UserPostStats ups
WHERE 
    ups.ActivityRank <= 10 
ORDER BY 
    ups.ActivityRank, ups.CreationDate DESC;
