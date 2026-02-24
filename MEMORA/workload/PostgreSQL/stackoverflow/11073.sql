
WITH PostAggregate AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT ba.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges ba ON p.OwnerUserId = ba.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'  
    GROUP BY 
        p.Id, p.PostTypeId
),
PostTypeAggregate AS (
    SELECT 
        pt.Id AS PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(*) AS TotalPosts,
        SUM(CommentCount) AS TotalComments,
        SUM(VoteCount) AS TotalVotes,
        SUM(UpVoteCount) AS TotalUpVotes,
        SUM(DownVoteCount) AS TotalDownVotes,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        PostAggregate pa
    JOIN 
        PostTypes pt ON pa.PostTypeId = pt.Id
    GROUP BY 
        pt.Id, pt.Name
)
SELECT 
    pta.PostTypeId,
    pta.PostTypeName,
    pta.TotalPosts,
    pta.TotalComments,
    pta.TotalVotes,
    pta.TotalUpVotes,
    pta.TotalDownVotes,
    pta.TotalBadges,
    ROUND(COALESCE(pta.TotalVotes, 0)::DECIMAL / NULLIF(pta.TotalPosts, 0), 2) AS AvgVotesPerPost,
    ROUND(COALESCE(pta.TotalComments, 0)::DECIMAL / NULLIF(pta.TotalPosts, 0), 2) AS AvgCommentsPerPost
FROM 
    PostTypeAggregate pta
ORDER BY 
    pta.TotalPosts DESC;
