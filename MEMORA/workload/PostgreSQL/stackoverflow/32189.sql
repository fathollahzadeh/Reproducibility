
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        P.Title,
        P.CreationDate,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.ParentId IS NULL  
    UNION ALL
    SELECT 
        P2.Id,
        P2.ParentId,
        P2.Title,
        P2.CreationDate,
        PH.Level + 1
    FROM 
        Posts P2
    INNER JOIN 
        PostHierarchy PH ON P2.ParentId = PH.PostId
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10  
),
PostVoteAggregates AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)
SELECT 
    PH.PostId,
    PH.Title,
    PH.CreationDate,
    PH.Level,
    PVA.UpVotes,
    PVA.DownVotes,
    PVA.TotalVotes,
    COALESCE(PT.TagName, 'No Tag') AS TopTag
FROM 
    PostHierarchy PH
LEFT JOIN 
    PostVoteAggregates PVA ON PH.PostId = PVA.PostId
LEFT JOIN 
    (SELECT 
         T.TagName, 
         P.Id AS PostId,
         ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY COUNT(*) DESC) AS TagRank
     FROM 
         Tags T
     JOIN 
         Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
     GROUP BY 
         T.TagName, P.Id) PT ON PH.PostId = PT.PostId AND PT.TagRank = 1
ORDER BY 
    PH.Level, PVA.UpVotes DESC, PH.CreationDate DESC;
