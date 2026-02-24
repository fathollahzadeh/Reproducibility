WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerName,
        u.Reputation AS OwnerReputation,
        pn.Comment AS LastEditComment,
        pn.UserDisplayName AS LastEditorName,
        pn.CreationDate AS LastEditDate,
        p.AnswerCount,
        p.CommentCount,
        array_length(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory pn ON p.LastEditorUserId = pn.UserId AND p.Id = pn.PostId 
    WHERE 
        p.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year') 
        AND p.PostTypeId IN (1, 2)  
)

SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.OwnerName,
    PD.OwnerReputation,
    PD.AnswerCount,
    PD.CommentCount,
    PD.TagCount,
    COUNT(c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    COUNT(DISTINCT pl.RelatedPostId) AS TotalRelatedPosts
FROM 
    PostDetails PD
LEFT JOIN 
    Comments c ON PD.PostId = c.PostId
LEFT JOIN 
    Votes v ON PD.PostId = v.PostId
LEFT JOIN 
    PostLinks pl ON PD.PostId = pl.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.CreationDate, PD.ViewCount, PD.OwnerName, PD.OwnerReputation, PD.AnswerCount, PD.CommentCount, PD.TagCount
ORDER BY 
    PD.ViewCount DESC, PD.AnswerCount DESC
LIMIT 50;