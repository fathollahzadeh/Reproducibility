WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
),
MostVotedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE(MAX(PH.CreationDate), P.CreationDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
    HAVING 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
),
TotalComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
RankedPosts AS (
    SELECT 
        MP.*,
        COALESCE(TC.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN MP.ViewCount > 1000 THEN 'High'
            WHEN MP.ViewCount BETWEEN 100 AND 1000 THEN 'Medium'
            ELSE 'Low' 
        END AS Popularity
    FROM 
        MostVotedPosts MP
    LEFT JOIN 
        TotalComments TC ON MP.PostId = TC.PostId
)
SELECT 
    RP.*,
    UR.DisplayName AS TopUser,
    UR.Reputation AS UserReputation
FROM 
    RankedPosts RP
JOIN 
    UserReputation UR ON RP.UpVotes = (SELECT MAX(UpVotes) FROM RankedPosts)
ORDER BY 
    RP.LastActivityDate DESC
LIMIT 10;
