
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COALESCE(SUM(vs.VoteCount), 0) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
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
    ) vs ON p.Id = vs.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(cp.Id) AS CommentCount,
        COALESCE(SUM(pvp.VoteCount), 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments cp ON p.Id = cp.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) pvp ON p.Id = pvp.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags
),

PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        TaggedPosts
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalVotes,
    us.TotalBadges,
    pt.TagName,
    pt.TagCount
FROM 
    UserStatistics us
LEFT JOIN 
    PopularTags pt ON us.TotalPosts >= 10 
ORDER BY 
    us.Reputation DESC, pt.TagCount DESC;
