
WITH StringProcessedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(BadgesReceived.BadgeCount, 0) AS BadgeCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ARRAY_LENGTH(string_to_array(p.Tags, '>'), 1) AS TagCount,
        LENGTH(p.Body) AS BodyLength,
        LENGTH(p.Title) AS TitleLength
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) AS BadgesReceived ON p.OwnerUserId = BadgesReceived.UserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.OwnerUserId, p.CreationDate, BadgesReceived.BadgeCount
),
AggregateData AS (
    SELECT 
        TagCount,
        AVG(BodyLength) AS AvgBodyLength,
        AVG(TitleLength) AS AvgTitleLength,
        SUM(CommentCount) AS TotalComments,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        StringProcessedPosts
    GROUP BY 
        TagCount
)
SELECT 
    ad.TagCount,
    ad.AvgBodyLength,
    ad.AvgTitleLength,
    ad.TotalComments,
    ad.TotalBadges,
    CASE 
        WHEN ad.TagCount < 5 THEN 'Low Tags'
        WHEN ad.TagCount BETWEEN 5 AND 10 THEN 'Medium Tags'
        ELSE 'High Tags'
    END AS TagCategory
FROM 
    AggregateData ad
ORDER BY 
    ad.TagCount;
