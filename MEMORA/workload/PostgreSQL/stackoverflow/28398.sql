
WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
FrequentTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalBounties,
        ROW_NUMBER() OVER (ORDER BY TotalBounties DESC, Reputation DESC) AS UserRank
    FROM 
        UserReputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        CA.TagName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        FrequentTags CA ON CA.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags) - 2), '><'))
    WHERE 
        P.PostTypeId = 1  
),
Analytics AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.TagName,
        PD.CreationDate,
        PD.Score,
        PD.ViewCount,
        PD.OwnerDisplayName,
        TU.DisplayName AS TopUserDisplayName
    FROM 
        PostDetails PD
    LEFT JOIN 
        TopUsers TU ON PD.OwnerDisplayName = TU.DisplayName  
)
SELECT 
    A.PostId,
    A.Title AS QuestionTitle,
    A.TagName,
    A.CreationDate,
    A.Score,
    A.ViewCount,
    A.OwnerDisplayName,
    COALESCE(A.TopUserDisplayName, 'Non-top User') AS TopUserIndicator
FROM 
    Analytics A
ORDER BY 
    A.ViewCount DESC, A.Score DESC
LIMIT 10;
