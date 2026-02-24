WITH TagCount AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tags
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2) AS TagList,
        COUNT(*) AS UsageCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tags
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        TC.PostCount AS TagPostCount,
        URep.QuestionCount,
        URep.Upvotes,
        URep.Downvotes,
        COALESCE(TC.PostCount, 0) AS TagUsage
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        TagCount TC ON P.Tags = TC.Tags
    LEFT JOIN 
        UserReputation URep ON U.Id = URep.UserId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.OwnerName,
    PD.OwnerReputation,
    PD.QuestionCount,
    PD.Upvotes,
    PD.Downvotes,
    PT.TagList,
    PD.TagUsage
FROM 
    PostDetails PD
JOIN 
    PopularTags PT ON PD.TagPostCount > 0
ORDER BY 
    PD.CreationDate DESC
LIMIT 100;