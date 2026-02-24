WITH RecursivePostHistory AS (
    SELECT 
        Ph.Id AS PostHistoryId,
        P.Id AS PostId,
        Ph.CreationDate,
        U.DisplayName AS UserDisplayName,
        Ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY Ph.PostId ORDER BY Ph.CreationDate DESC) AS HistoryOrder
    FROM 
        PostHistory Ph
    JOIN 
        Posts P ON Ph.PostId = P.Id
    JOIN 
        Users U ON Ph.UserId = U.Id
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.PostTypeId,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        (
            SELECT COUNT(*)
            FROM Comments C
            WHERE C.PostId = P.Id
        ) AS CommentCount,
        (
            SELECT COUNT(*)
            FROM Votes V
            WHERE V.PostId = P.Id AND V.VoteTypeId = 2  
        ) AS UpvoteCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
AggregatedScores AS (
    SELECT 
        RP.OwnerDisplayName,
        SUM(RP.Score) AS TotalScore,
        SUM(RP.ViewCount) AS TotalViews,
        AVG(RP.UpvoteCount) AS AvgUpvotes
    FROM 
        RecentPosts RP
    GROUP BY 
        RP.OwnerDisplayName
),
TopContributors AS (
    SELECT 
        OwnerDisplayName,
        TotalScore,
        TotalViews,
        AvgUpvotes,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        AggregatedScores
)
SELECT 
    PCA.PostHistoryId,
    PCA.PostId,
    PCA.UserDisplayName,
    PCA.Comment,
    PCA.CreationDate,
    T.OwnerDisplayName,
    T.TotalScore,
    T.TotalViews,
    T.AvgUpvotes
FROM 
    RecursivePostHistory PCA
JOIN 
    Posts P ON PCA.PostId = P.Id
JOIN 
    TopContributors T ON PCA.UserDisplayName = T.OwnerDisplayName
WHERE 
    PCA.HistoryOrder <= 5  
ORDER BY 
    PCA.CreationDate DESC, 
    T.TotalScore DESC;