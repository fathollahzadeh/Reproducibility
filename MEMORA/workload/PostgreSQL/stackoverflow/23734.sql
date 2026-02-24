WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(VOT.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(VOT.DownVotes, 0)) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(P.Score) DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VOT ON P.Id = VOT.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalScore,
        PS.ScoreRank,
        (PS.TotalUpVotes - PS.TotalDownVotes) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        PostCount,
        TotalScore,
        ScoreRank,
        NetVotes
    FROM 
        UserPostStats
    WHERE 
        ScoreRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.BadgeCount,
    TU.PostCount,
    TU.TotalScore,
    TU.NetVotes,
    CASE 
        WHEN TU.NetVotes IS NULL THEN 'No Votes'
        WHEN TU.NetVotes > 50 THEN 'Highly Voted'
        WHEN TU.NetVotes BETWEEN 20 AND 50 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VotingCategory,
    COALESCE(ARRAY_AGG(DISTINCT T.TagName) FILTER (WHERE T.TagName IS NOT NULL), '{}') AS TagsContributed
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(P.Tags, '><')) AS TagName
    ) T ON TRUE
GROUP BY 
    TU.UserId, TU.DisplayName, TU.BadgeCount, TU.PostCount, TU.TotalScore, TU.NetVotes
ORDER BY 
    TU.TotalScore DESC, TU.BadgeCount DESC;