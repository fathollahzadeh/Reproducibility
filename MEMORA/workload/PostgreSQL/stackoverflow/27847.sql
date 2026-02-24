WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <')) AS tag ON 
        p.PostTypeId = 1  
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        t.Count > 100   
),
PopularTagStats AS (
    SELECT 
        t.TagName AS PopularTag,
        COUNT(rp.PostId) AS PostsCount,
        AVG(rp.Score) AS AvgScore,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.AnswerCount) AS TotalAnswers
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.Rank <= 5  
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT ba.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges ba ON u.Id = ba.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    pts.PopularTag,
    pts.PostsCount,
    pts.AvgScore,
    pts.TotalViews,
    pts.TotalAnswers,
    ue.UserId,
    ue.DisplayName,
    ue.Reputation,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.TotalComments,
    ue.TotalBadges
FROM 
    PopularTagStats pts
JOIN 
    UserEngagement ue ON ue.Reputation > 1000  
ORDER BY 
    pts.PostsCount DESC, pts.TotalViews DESC;