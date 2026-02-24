
WITH PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 WHEN V.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS Score,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        EXTRACT(YEAR FROM P.CreationDate) AS YearCreated
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Tags, U.DisplayName
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
    GROUP BY 
        T.TagName
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.BountyAmount) AS TotalBounty,
        COUNT(P.Id) AS PostsCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        TotalBounty DESC
    LIMIT 5
),
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 6, 24) 
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)

SELECT 
    P.Title,
    P.OwnerDisplayName,
    P.CommentCount,
    Tag.TagName,
    Tag.PostCount,
    Tag.TotalViews,
    Tag.TotalAnswers,
    U.DisplayName AS TopUser,
    U.TotalBounty,
    U.PostsCount,
    PH.EditCount
FROM 
    PostAggregates P
LEFT JOIN 
    TagStats Tag ON P.Tags LIKE CONCAT('%<', Tag.TagName, '>%')
LEFT JOIN 
    TopUsers U ON P.OwnerDisplayName = U.DisplayName
LEFT JOIN 
    PostHistoryAnalysis PH ON P.PostId = PH.PostId
WHERE 
    P.YearCreated = (SELECT MAX(YearCreated) FROM PostAggregates) 
ORDER BY 
    P.CommentCount DESC, P.Score DESC;
