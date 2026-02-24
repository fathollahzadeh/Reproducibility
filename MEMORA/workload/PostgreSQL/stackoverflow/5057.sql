
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(rp.PostId) AS QuestionsAsked,
    SUM(rp.CommentCount) AS TotalComments,
    SUM(rp.Upvotes) AS TotalUpvotes,
    SUM(rp.Downvotes) AS TotalDownvotes,
    MAX(rp.CreationDate) AS LastQuestionDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    rp.UserPostRank <= 3 
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    QuestionsAsked DESC, TotalUpvotes DESC, TotalComments DESC;
