
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(B.Class) AS TotalBadgeClass,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalBadgeClass,
        TotalPosts,
        QuestionsCount,
        AnswersCount
    FROM 
        UserReputation
    WHERE 
        TotalPosts > 0
    ORDER BY 
        TotalBadgeClass DESC, TotalPosts DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(P.Tags, '><')) AS TagName
        ) AS T ON TRUE
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id, U.DisplayName
),
HighlyVotedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes
    GROUP BY 
        PostId
    HAVING 
        COUNT(*) > 5 
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        PD.OwnerDisplayName,
        PD.CreationDate,
        PD.Tags,
        COALESCE(HVP.VoteCount, 0) AS VoteCount
    FROM 
        PostDetails PD
    LEFT JOIN 
        HighlyVotedPosts HVP ON PD.PostId = HVP.PostId
)
SELECT 
    TU.DisplayName AS TopUser,
    RP.Title AS PostTitle,
    RP.Score AS PostScore,
    RP.ViewCount AS PostViews,
    RP.VoteCount AS PostVotes,
    RP.CreationDate AS PostCreationDate,
    RP.Tags AS PostTags
FROM 
    RankedPosts RP
JOIN 
    TopUsers TU ON RP.OwnerDisplayName = TU.DisplayName
ORDER BY 
    TU.TotalBadgeClass DESC, RP.Score DESC, RP.VoteCount DESC;
