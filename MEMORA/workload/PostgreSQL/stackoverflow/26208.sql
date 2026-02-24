
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
        P.Body
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS tag_name ON TRUE
    LEFT JOIN 
        Tags T ON tag_name = T.TagName
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName, U.Reputation, P.Body
),
PopularPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.OwnerDisplayName,
        PD.OwnerReputation,
        PD.CommentCount,
        PD.Tags,
        PD.Body,
        ROW_NUMBER() OVER (ORDER BY PD.Score DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    UB.BadgeCount,
    UB.Badges,
    PP.Title AS PopularPostTitle,
    PP.CreationDate AS PostDate,
    PP.OwnerReputation,
    PP.CommentCount,
    PP.Tags
FROM 
    UserBadges UB
JOIN 
    PopularPosts PP ON PP.Rank <= 10 AND PP.OwnerDisplayName = UB.DisplayName
ORDER BY 
    UB.BadgeCount DESC, PP.Score DESC;
