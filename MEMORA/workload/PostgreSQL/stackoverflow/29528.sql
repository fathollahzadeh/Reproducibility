
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
TagAnalytics AS (
    SELECT 
        TRIM(unnest(string_to_array(Tags, '><'))) AS TagName, 
        COUNT(TQ.PostId) AS TotalQuestions,
        SUM(TQ.CommentCount) AS TotalComments,
        SUM(TQ.UpvoteCount) AS TotalUpvotes,
        SUM(TQ.DownvoteCount) AS TotalDownvotes
    FROM
        TopQuestions TQ
    GROUP BY 
        TRIM(unnest(string_to_array(Tags, '><')))
)
SELECT 
    ta.TagName,
    ta.TotalQuestions,
    ta.TotalComments,
    ta.TotalUpvotes,
    ta.TotalDownvotes,
    CASE 
        WHEN ta.TotalQuestions > 50 THEN 'Highly Discussed'
        WHEN ta.TotalQuestions BETWEEN 20 AND 50 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel
FROM 
    TagAnalytics ta
ORDER BY 
    ta.TotalQuestions DESC;
